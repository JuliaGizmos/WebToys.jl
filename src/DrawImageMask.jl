"""
    DrawImageMask(image)

An interactive widget that allows you to draw a mask on top of an image.

# Examples
```julia
# Notebook Cell 1
using WebToys, FileIO
my_image = load("./path/to/image.png")
mask_widget = DrawImageMask(my_image)

# Notebook Cell 2
# Draw on top of the image in the notebook output before running this cell.
masked_image = my_image .* getmask(mask_widget)
```
"""
struct DrawImageMask
    s::Scope
    base_image
end

function DrawImageMask(
    base_image::Array{T, 2}
    ;
    brush_size::Integer=20,
    brush_color::String="black",
) where {T}
    height, width = size(base_image)
    scope = Scope()
    data_url = Observable(scope, "data", "")
    image = Observable{Any}(scope, "mask", nothing; sync=false)
    map!(parseb64png, image, data_url)

    base_img = node(
        :img,
        src=image_to_data_url(base_image),
        height=height,
        width=width,
        draggable=false,
        style=Dict(
            "position" => "absolute",
            "top" => "0",
            "left" => "0",
        ),
    )

    canvas = node(
        :canvas,
        height=height,
        width=width,
        style=Dict(
            "display" => "block",
            # Note: z-index is used to make sure canvas displays on top of the
            # img elt, and position: relative is required for z-index to take
            # effect.
            "z-index" => "10",
            "position" => "relative",
        ),
    )

    canvas_and_base_img = node(
        :div,
        base_img,
        canvas,
        style=Dict(
            "position" => "relative",
            "border" => "1px solid #ccc",
            "background" => "white",
        ),
    )

    clear_button = node(
        :button,
        "Clear",
        events=Dict(
            "click" => js"""
                function() {
                    const canvas = _webIOScope.dom.querySelector("canvas");
                    canvas.clear();
                    _webIOScope.setObservableValue("data", "");
                }
                """
        )
    )

    scope(flexcol(
        canvas_and_base_img,
        clear_button,
    ))

    onmount(scope,
        js"""
        function() {
            const BASE_IMAGE_SRC = $(image_to_data_url(base_image));
            const canvas = this.dom.querySelector("canvas");
            let path = [];

            canvas.clear = function () {
                path = [];
                redraw();
            }

            const context = canvas.getContext("2d");
            context.lineWidth = $(brush_size);
            context.strokeStyle = $(brush_color);
            context.lineJoin = "round";

            let lastPoint = [0, 0];
            let isDrawing = false;

            drawBaseImage();

            function currentPoint(e) {
                const rect = canvas.getBoundingClientRect();
                return [e.clientX - rect.left, e.clientY - rect.top];
            }

            function redraw() {
                console.log("redraw", path);
                canvas.getContext("2d").clearRect(0, 0, canvas.width, canvas.height);
                context.lineWidth = $(brush_size);
                context.strokeStyle = $(brush_color);
                context.lineJoin = "round";
                context.lineCap = "round";
                drawBaseImage();
                let last = null;
                for (const point of [...path, null]) {
                    if (last === null) {
                        console.log("continue");
                        last = point;
                        continue;
                    }
                    if (point === null) {
                        last = point;
                        continue;
                    }
                    drawLine(last, point);
                    last = point;
                }
                context.closePath();
            }

            function drawLine(begin, end) {
                context.beginPath();
                context.moveTo(...begin);
                context.lineTo(...end);
                context.stroke();
            }

            function drawBaseImage() {
                return;
                console.log("drawBaseImage");
                const context = canvas.getContext("2d");
                canvas.height = $(height);
                canvas.width = $(width);
                const image = new Image();
                image.src = BASE_IMAGE_SRC;
                context.drawImage(image, 0, 0);
            }

            canvas.addEventListener("mousemove", (event) => {
                const point = currentPoint(event);
                if (isDrawing) {
                    path.push(point);
                    redraw();
                }
                lastPoint = point;
            });

            canvas.addEventListener("mousedown", (event) => {
                lastPoint = currentPoint(event);
                isDrawing = true;
            });

            // Note: we do window here to handle when the mouseup happens outside of the
            // canvas element
            window.addEventListener("mouseup", (event) => {
                if (!isDrawing) {
                    return;
                }
                this.setObservableValue("data", canvas.toDataURL())
                isDrawing = false;
                path.push(null);
            });
        }
        """
    )
    return DrawImageMask(scope, base_image)
end

@WebIO.register_renderable(DrawImageMask) do c
    return WebIO.render(c.s)
end

"""
    getmask(widg::DrawImageMask)

Get the bitmask
"""
function getmask(widg::DrawImageMask)::BitArray{2}
    mask = widg.s["mask"][]
    if mask === nothing
        error("No mask has been drawn!")
    end
    return mask .== 1.0
end
