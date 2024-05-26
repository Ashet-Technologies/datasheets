function slurp(fn)
  local f = assert(io.open(fn, "rb"))
  local all = f:read("*all")
  f:close()
  return all
end

function capture(command)
  local p = assert(io.popen(command, "r"))
  local str = assert(p:read("*all"))
  p:close()
  return str
end

local template = slurp("templates/datasheet.fodt") -- capture("awk -f template-snipper.awk templates/datasheet.fodt")

local months = {
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
}

local opendocument_patches = {
  ["Heading_20_1"] = "Title",
  ["Heading_20_2"] = "Heading 1",
  ["Heading_20_3"] = "Heading 2",
  ["Heading_20_4"] = "Heading 3",
  ["Heading_20_5"] = "Heading 4",
  ["Heading_20_6"] = "Heading 5",
  ["Source_Text"] = "Preformatted_20_Text",
  ["Text_20_body"] = "Text Body",
  ["First_20_paragraph"] = "Paragraph.Default",
}

local function renderDocument(output_path, template, parameters)
  local function replacePattern(full_match, name)
    local id = name:gsub(" +$", "")
    -- print(full_match, '"' .. id .. '"')
    return parameters[id]
  end

  local string = template:gsub("(%[([ %w]+)%])", replacePattern)

  local f = assert(io.open(output_path, "wb"))
  f:write(string)
  f:close()
end

local function loadDocument(path)

  local raw_md = slurp(path)

  local lua_header, markdown_source = raw_md:match("(%b{})(.*)")

  local header_env = { 
    -- values for "type"
    APPNOTE = "appnote",
    DATASHEET = "datasheet",
    MANUAL = "manual",
    SPECIFICATION = "specification",

    -- values for "status"
    DRAFT = "draft",
    PUBLISHED = "published",
  }

  function header_env.Date(y, m, d)
    return { day = assert(tonumber(d)), month = assert(tonumber(m)), year = assert(tonumber(y)) }
  end

  function header_env.Version(major, minor, patch)
    return { major = assert(tonumber(major)), minor = assert(tonumber(minor)), patch = assert(tonumber(patch or 0)) }
  end

  local header_gen = assert(load("return " .. lua_header, path, "bt", header_env))

  local header = header_gen()

  doc = {
    type = assert(tostring(header.type)),
    status = assert(tostring(header.status)),
    title = assert(tostring(header.title)),
    part = assert(tostring(header.part)),
    date = assert(header.date),
    revision = assert(header.revision),

    source = assert(tostring(markdown_source)),
  }

  assert(
       doc.type == header_env.APPNOTE 
    or doc.type == header_env.DATASHEET 
    or doc.type == header_env.MANUAL 
  )

  assert(
       doc.status == header_env.DRAFT
    or doc.status == header_env.PUBLISHED
  )

  assert(doc.status ~= header_env.PUBLISHED or doc.revision.major > 0)

  return doc
end

local function renderToXml(source_code)

  local f = assert(io.open("temp/document.md", "wb"))
  f:write(source_code)
  f:close()

  local body = capture("pandoc -f gfm -t opendocument -s --template templates/datasheet.fodt temp/document.md")

  -- for original, replacement in pairs(opendocument_patches) do
  --   body = body:gsub(original, replacement)
  -- end

  return body
end

local function convertFile(source_file, mode)

  assert(mode == "release" or mode == "draft")

  local base_name = assert(source_file:match("([%w\\-]+)%.%w+$"))

  local doc = loadDocument(source_file)

  if mode == "release" and doc.status ~= "published" then 
    return nil
  end

  local body = renderToXml(doc.source)

  renderDocument(
    "temp/" .. base_name .. ".fodt", body, {
      ["DOCUMENT DATE"] = ("%s %04d"):format(months[doc.date.month], doc.date.year),
      ["DOCUMENT PART"] = doc.part,
      ["DOCUMENT TITLE"] = doc.title,
      ["DOCUMENT ALTDATE"] = ("%s/%02d"):format(months[doc.date.month]:sub(1, 3), doc.date.year % 100),
      ["DOCUMENT REVISION"] = (doc.revision.major > 0 and ("v%d.%d"):format(doc.revision.major, doc.revision.minor)
        or "PROTOTYPE"),
    }
  )

  capture("libreoffice --headless --convert-to pdf --outdir temp/ temp/" .. base_name .. ".fodt")

  output_file = "temp/" .. base_name .. ".pdf"

  os.remove("temp/" .. base_name .. ".fodt")
  os.remove("temp/document.md")

  return {
    folder = doc.type .. "s",
    file = output_file,
  }
end

if #arg < 1 then
  io.stderr:write("render.lua <source-md> [release|draft]\n")
  os.exit(1)
end

renderMode = "release"
if #arg == 2 then 
  renderMode = arg[2]
end

output = convertFile(arg[1], renderMode)
if output then
  io.stdout:write(
    output.folder .. ":" .. output.file .. "\n"
  )
end