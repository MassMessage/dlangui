module dlangui.widgets.controls;

import dlangui.widgets.widget;



/// static text widget
class TextWidget : Widget {
    this(string ID = null) {
		super(ID);
        styleId = "TEXT";
    }
    protected dstring _text;
    /// get widget text
    override @property dstring text() { return _text; }
    /// set text to show
    override @property Widget text(dstring s) { 
        _text = s; 
        requestLayout();
		return this;
    }

    override void measure(int parentWidth, int parentHeight) { 
        FontRef font = font();
        Point sz = font.textSize(text);
        measuredContent(parentWidth, parentHeight, sz.x, sz.y);
    }

    bool onClick() {
        // override it
        Log.d("Button.onClick ", id);
        return false;
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        ClipRectSaver(buf, rc);
        applyPadding(rc);
        FontRef font = font();
        Point sz = font.textSize(text);
        applyAlign(rc, sz);
        font.drawText(buf, rc.left, rc.top, text, textColor);
    }
}

/// image widget
class ImageWidget : Widget {

    protected string _drawableId;
    protected DrawableRef _drawable;

    this(string ID = null, string drawableId = null) {
		super(ID);
        _drawableId = drawableId;
	}

    /// get drawable image id
    @property string drawableId() { return _drawableId; }
    /// set drawable image id
    @property ImageWidget drawableId(string id) { 
        _drawableId = id; 
        _drawable.clear();
        requestLayout();
        return this; 
    }
    /// get drawable
    @property ref DrawableRef drawable() {
        if (!_drawable.isNull)
            return _drawable;
        if (_drawableId !is null)
            _drawable = drawableCache.get(_drawableId);
        return _drawable;
    }
    /// set custom drawable (not one from resources)
    @property ImageWidget drawable(DrawableRef img) {
        _drawable = img;
        _drawableId = null;
        return this;
    }

    override void measure(int parentWidth, int parentHeight) { 
        DrawableRef img = drawable;
        int w = 0;
        int h = 0;
        if (!img.isNull) {
            w = img.width;
            h = img.height;
        }
        measuredContent(parentWidth, parentHeight, w, h);
    }
    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        ClipRectSaver(buf, rc);
        applyPadding(rc);
        DrawableRef img = drawable;
        if (!img.isNull) {
            Point sz;
            sz.x = img.width;
            sz.y = img.height;
            applyAlign(rc, sz);
            img.drawTo(buf, rc);
        }
    }
}

/// button with image only
class ImageButton : ImageWidget {
    this(string ID = null, string drawableId = null) {
        super(ID);
        styleId = "BUTTON";
        _drawableId = drawableId;
        trackHover = true;
    }
}

class Button : Widget {
    protected dstring _text;
    override @property dstring text() { return _text; }
    override @property Widget text(dstring s) { _text = s; requestLayout(); return this; }
    this(string ID = null) {
		super(ID);
        styleId = "BUTTON";
        trackHover = true;
    }

    override void measure(int parentWidth, int parentHeight) { 
        FontRef font = font();
        Point sz = font.textSize(text);
        measuredContent(parentWidth, parentHeight, sz.x, sz.y);
    }

	override void onDraw(DrawBuf buf) {
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        buf.fillRect(_pos, backgroundColor);
        applyPadding(rc);
        ClipRectSaver(buf, rc);
        FontRef font = font();
        Point sz = font.textSize(text);
        applyAlign(rc, sz);
        font.drawText(buf, rc.left, rc.top, text, textColor);
    }

}

/// scroll bar - either vertical or horizontal
class ScrollBar : WidgetGroup, OnClickHandler {
    protected ImageButton _btnBack;
    protected ImageButton _btnForward;
    protected SliderButton _indicator;
    protected PageScrollButton _pageUp;
    protected PageScrollButton _pageDown;
    protected Rect _scrollArea;
    protected int _btnSize;
    protected int _minIndicatorSize;
    protected int _minValue = 0;
    protected int _maxValue = 100;
    protected int _pageSize = 30;
    protected int _position = 20;

    @property int position() { return _position; }
    @property ScrollBar position(int newPosition) { 
        if (_position != newPosition) {
            _position = newPosition;
            requestLayout();
        }
        return this;
    }
    @property int minValue() { return _minValue; }
    @property int maxValue() { return _maxValue; }
    @property int pageSize() { return _pageSize; }
    @property ScrollBar pageSize(int size) {
        if (_pageSize != size) {
            _pageSize = size;
            requestLayout();
        }
        return this;
    }
    ScrollBar setRange(int min, int max) {
        if (_minValue != min || _maxValue != max) {
            _minValue = min;
            _maxValue = max;
            requestLayout();
        }
        return this;
    }

    class PageScrollButton : Widget {
        this(string ID) {
            super(ID);
            styleId = "PAGE_SCROLL";
            trackHover = true;
        }
    }

    class SliderButton : ImageButton {
        Point _dragStart;
        int _dragStartPosition;
        bool _dragging;
        Rect _dragStartRect;

        this(string resourceId) {
            super("SLIDER", resourceId);
            trackHover = true;
        }

        /// process mouse event; return true if event is processed by widget.
        override bool onMouseEvent(MouseEvent event) {
            // support onClick
            if (event.action == MouseAction.ButtonDown && event.button == MouseButton.Left) {
                setState(State.Pressed);
                _dragging = true;
                _dragStart.x = event.x;
                _dragStart.y = event.y;
                _dragStartPosition = _position;
                _dragStartRect = _pos;
                return true;
            }
            if (event.action == MouseAction.FocusOut && _dragging) {
                return true;
            }
            if (event.action == MouseAction.Move && _dragging) {
                int delta = _orientation == Orientation.Vertical ? event.y - _dragStart.y : event.x - _dragStart.x;
                Rect rc = _dragStartRect;
                int offset;
                int space;
                if (_orientation == Orientation.Vertical) {
                    rc.top += delta;
                    rc.bottom += delta;
                    if (rc.top < _scrollArea.top) {
                        rc.top = _scrollArea.top;
                        rc.bottom = _scrollArea.top + _dragStartRect.height;
                    } else if (rc.bottom > _scrollArea.bottom) {
                        rc.top = _scrollArea.bottom - _dragStartRect.height;
                        rc.bottom = _scrollArea.bottom;
                    }
                    offset = rc.top - _scrollArea.top;
                    space = _scrollArea.height - rc.height;
                } else {
                    rc.left += delta;
                    rc.right += delta;
                    if (rc.left < _scrollArea.left) {
                        rc.left = _scrollArea.left;
                        rc.right = _scrollArea.left + _dragStartRect.width;
                    } else if (rc.right > _scrollArea.right) {
                        rc.left = _scrollArea.right - _dragStartRect.width;
                        rc.right = _scrollArea.right;
                    }
                    offset = rc.left - _scrollArea.left;
                    space = _scrollArea.width - rc.width;
                }
                layoutButtons(rc);
                //_pos = rc;
                int position = space > 0 ? _minValue + offset * (_maxValue - _minValue - _pageSize) / space : 0;
                invalidate();
                onIndicatorDragging(_dragStartPosition, position);
                return true;
            }
            if (event.action == MouseAction.ButtonUp && event.button == MouseButton.Left) {
                resetState(State.Pressed);
                if (_dragging) {

                    _dragging = false;
                }
                return true;
            }
            if (event.action == MouseAction.Move && trackHover) {
                if (!(state & State.Hover)) {
                    Log.d("Hover ", id);
                    setState(State.Hover);
                }
	            return true;
            }
            if ((event.action == MouseAction.Leave || event.action == MouseAction.Cancel) && trackHover) {
                Log.d("Leave ", id);
	            resetState(State.Hover);
	            return true;
            }
            if (event.action == MouseAction.Cancel) {
                Log.d("SliderButton.onMouseEvent event.action == MouseAction.Cancel");
                resetState(State.Pressed);
                _dragging = false;
                return true;
            }
            return false;
        }

    }

    protected bool onIndicatorDragging(int initialPosition, int currentPosition) {
        _position = currentPosition;
        return true;
    }

    private bool calcButtonSizes(int availableSize, ref int spaceBackSize, ref int spaceForwardSize, ref int indicatorSize) {
        int dv = _maxValue - _minValue;
        if (_pageSize >= dv) {
            // full size
            spaceBackSize = spaceForwardSize = 0;
            indicatorSize = availableSize;
            return false;
        }
        if (dv < 0)
            dv = 0;
        indicatorSize = _pageSize * availableSize / dv;
        if (indicatorSize < _minIndicatorSize)
            indicatorSize = _minIndicatorSize;
        if (indicatorSize >= availableSize) {
            // full size
            spaceBackSize = spaceForwardSize = 0;
            indicatorSize = availableSize;
            return false;
        }
        int spaceLeft = availableSize - indicatorSize;
        int topv = _position - _minValue;
        int bottomv = _position + _pageSize - _minValue;
        if (topv < 0)
            topv = 0;
        if (bottomv > dv)
            bottomv = dv;
        bottomv = dv - bottomv;
        spaceBackSize = spaceLeft * topv / (topv + bottomv);
        spaceForwardSize = spaceLeft - spaceBackSize;
        return true;
    }

    protected Orientation _orientation = Orientation.Vertical;
    /// returns scrollbar orientation (Vertical, Horizontal)
    @property Orientation orientation() { return _orientation; }
    /// sets scrollbar orientation
    @property ScrollBar orientation(Orientation value) { 
        if (_orientation != value) {
            _orientation = value; 
            _btnBack.drawableId = style.customDrawableId(_orientation == Orientation.Vertical ? ATTR_SCROLLBAR_BUTTON_UP : ATTR_SCROLLBAR_BUTTON_LEFT);
            _btnForward.drawableId = style.customDrawableId(_orientation == Orientation.Vertical ? ATTR_SCROLLBAR_BUTTON_DOWN : ATTR_SCROLLBAR_BUTTON_RIGHT);
            _indicator.drawableId = style.customDrawableId(_orientation == Orientation.Vertical ? ATTR_SCROLLBAR_INDICATOR_VERTICAL : ATTR_SCROLLBAR_INDICATOR_HORIZONTAL);
            requestLayout(); 
        }
        return this; 
    }

    this(string ID = null, Orientation orient = Orientation.Vertical) {
		super(ID);
        styleId = "SCROLLBAR";
        _orientation = orient;
        _btnBack = new ImageButton("BACK", style.customDrawableId(_orientation == Orientation.Vertical ? ATTR_SCROLLBAR_BUTTON_UP : ATTR_SCROLLBAR_BUTTON_LEFT));
        _btnForward = new ImageButton("FORWARD", style.customDrawableId(_orientation == Orientation.Vertical ? ATTR_SCROLLBAR_BUTTON_DOWN : ATTR_SCROLLBAR_BUTTON_RIGHT));
        _pageUp = new PageScrollButton("PAGE_UP");
        _pageDown = new PageScrollButton("PAGE_DOWN");
        _btnBack.styleId("SCROLLBAR_BUTTON");
        _btnForward.styleId("SCROLLBAR_BUTTON");
        _indicator = new SliderButton(style.customDrawableId(_orientation == Orientation.Vertical ? ATTR_SCROLLBAR_INDICATOR_VERTICAL : ATTR_SCROLLBAR_INDICATOR_HORIZONTAL));
        addChild(_btnBack);
        addChild(_btnForward);
        addChild(_indicator);
        addChild(_pageUp);
        addChild(_pageDown);
        _btnBack.onClickListener = &onClick;
        _btnForward.onClickListener = &onClick;
        _pageUp.onClickListener = &onClick;
        _pageDown.onClickListener = &onClick;
    }

    override void measure(int parentWidth, int parentHeight) { 
        Point sz;
        _btnBack.measure(parentWidth, parentHeight);
        _btnForward.measure(parentWidth, parentHeight);
        _indicator.measure(parentWidth, parentHeight);
        _pageUp.measure(parentWidth, parentHeight);
        _pageDown.measure(parentWidth, parentHeight);
        _btnSize = _btnBack.measuredWidth;
        _minIndicatorSize = _orientation == Orientation.Vertical ? _indicator.measuredHeight : _indicator.measuredWidth;
        if (_btnSize < _btnBack.measuredHeight)
            _btnSize = _btnBack.measuredHeight;
        if (_btnSize < 16)
            _btnSize = 16;
        if (_orientation == Orientation.Vertical) {
            // vertical
            sz.x = _btnSize;
            sz.y = _btnSize * 5; // min height
        } else {
            // horizontal
            sz.y = _btnSize;
            sz.x = _btnSize * 5; // min height
        }
        measuredContent(parentWidth, parentHeight, sz.x, sz.y);
    }

    protected void layoutButtons(Rect irc) {
        Rect r;
        _indicator.visibility = Visibility.Visible;
        if (_orientation == Orientation.Vertical) {
            _indicator.layout(irc);
            if (_scrollArea.top < irc.top) {
                r = _scrollArea;
                r.bottom = irc.top;
                _pageUp.layout(r);
                _pageUp.visibility = Visibility.Visible;
            } else {
                _pageUp.visibility = Visibility.Invisible;
            }
            if (_scrollArea.bottom > irc.bottom) {
                r = _scrollArea;
                r.top = irc.bottom;
                _pageDown.layout(r);
                _pageDown.visibility = Visibility.Visible;
            } else {
                _pageDown.visibility = Visibility.Invisible;
            }
        } else {
            _indicator.layout(irc);
            if (_scrollArea.left < irc.left) {
                r = _scrollArea;
                r.right = irc.left;
                _pageUp.layout(r);
                _pageUp.visibility = Visibility.Visible;
            } else {
                _pageUp.visibility = Visibility.Invisible;
            }
            if (_scrollArea.right > irc.right) {
                r = _scrollArea;
                r.left = irc.right;
                _pageDown.layout(r);
                _pageDown.visibility = Visibility.Visible;
            } else {
                _pageDown.visibility = Visibility.Invisible;
            }
        }
    }

    override void layout(Rect rc) {
        applyMargins(rc);
        applyPadding(rc);
        Rect r;
        if (_orientation == Orientation.Vertical) {
            // vertical
            // buttons
            int backbtnpos = rc.top + _btnSize;
            int fwdbtnpos = rc.bottom - _btnSize;
            r = rc;
            r.bottom = backbtnpos;
            _btnBack.layout(r);
            r = rc;
            r.top = fwdbtnpos;
            _btnForward.layout(r);
            // indicator
            r = rc;
            r.top = backbtnpos;
            r.bottom = fwdbtnpos;
            _scrollArea = r;
            int spaceBackSize, spaceForwardSize, indicatorSize;
            bool indicatorVisible = calcButtonSizes(r.height, spaceBackSize, spaceForwardSize, indicatorSize);
            Rect irc = r;
            irc.top += spaceBackSize;
            irc.bottom -= spaceForwardSize;
            layoutButtons(irc);
        } else {
            // horizontal
            int backbtnpos = rc.left + _btnSize;
            int fwdbtnpos = rc.right - _btnSize;
            r = rc;
            r.right = backbtnpos;
            _btnBack.layout(r);
            r = rc;
            r.left = fwdbtnpos;
            _btnForward.layout(r);
            // indicator
            r = rc;
            r.left = backbtnpos;
            r.right = fwdbtnpos;
            _scrollArea = r;
            int spaceBackSize, spaceForwardSize, indicatorSize;
            bool indicatorVisible = calcButtonSizes(r.width, spaceBackSize, spaceForwardSize, indicatorSize);
            Rect irc = r;
            irc.left += spaceBackSize;
            irc.right -= spaceForwardSize;
            layoutButtons(irc);
        }
        _pos = rc;
        _needLayout = false;
    }

    override bool onClick(Widget source) {
        Log.d("Scrollbar.onClick ", source.id);
        return true;
    }

    /// Draw widget at its position to buffer
    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        applyPadding(rc);
        ClipRectSaver(buf, rc);
        _btnForward.onDraw(buf);
        _btnBack.onDraw(buf);
        _pageUp.onDraw(buf);
        _pageDown.onDraw(buf);
        _indicator.onDraw(buf);
    }
}