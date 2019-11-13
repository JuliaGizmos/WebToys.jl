function parseb64png(payload::AbstractString)
    if isempty(payload)
        return nothing
    end

    if !startswith(payload, "data:image/png;base64")
        error("Argument to parseb64png must start with \"data:image/png;base64\".")
    end
    payload = replace(payload, "data:image/png;base64," => "")
    data = base64decode(payload)

    data = 1.0 .- map(convert(Matrix{RGBA{N0f8}}, ImageMagick.load_(data))) do c
        Float64(alpha(c))
    end
    return data
end

function image_to_b64png(image)::String
    io = IOBuffer()
    save(Stream(format"PNG", io), image)
    return base64encode(take!(io))
end

function image_to_data_url(image)::String
    payload = image_to_b64png(image)
    return "data:image/png;base64," * payload
end
