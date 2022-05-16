using Ion
Ion.command_main(["-h"])
Ion.command_main(["release", "-h"])
Ion.command_main(["create", "-h"])
Ion.command_main(["clone", "-h"])
Ion.command_main(["package", "-h"])
Ion.command_main(["format", "-h"])

cd(tempdir()) do
    Ion.command_main(["clone", "Bloqade", "-f", "-y"])
    Ion.command_main(["format", "Bloqade"])
    Ion.command_main(["create", "FakePkg"])
end
