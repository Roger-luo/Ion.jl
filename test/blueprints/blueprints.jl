using Ion
using Ion.Internal.Blueprints

t = Template(
    name="test",
    src=SrcDir()
)

using Configurations

to_toml(t)|>print


s = """
name = "test"

[project]
version = "0.1.0"
deps = []

[src]
"""

using TOML
d = TOML.parse(s)
t = from_dict(Template, d)

create(t, pkgdir(Ion, "test", "TestProject"); name="TestName", force=true)

t = from_toml(Template, pkgdir(Ion, "blueprints", "project.toml"))
create(t, pkgdir(Ion, "test", "TestProject"); name="TestName", force=true)
