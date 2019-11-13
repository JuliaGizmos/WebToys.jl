const flexrow = dom"div"(
    style=Dict(
        "position" => "relative",
        "display" => "flex",
        "flex-direction" => "row",
        "align-items" => "center",
        "justify-content" => "space-evenly",
    )
)

const flexcol = dom"div"(
    style=Dict(
        "position" => "relative",
        "display" => "flex",
        "flex-direction" => "column",
        "align-items" => "center",
        "justify-content" => "space-evenly",
    )
)
