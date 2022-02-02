using Ion
using Git
using Ion.Internal
using Test

@testset "is_version_number" begin
    @test Internal.is_version_number("0.1.2") == true
    @test Internal.is_version_number("0.1.x") == false
end

# clone some example repos
Ion.Internal.clone("Comonicon", pkgdir(Ion, "test", "repos"))
Ion.Internal.clone("Example", pkgdir(Ion, "test", "repos"))
Ion.Internal.clone("PlutoSliderServer", pkgdir(Ion, "test", "repos"))

@testset "ProjectToRelease" begin
    project = Internal.ProjectToRelease("patch", pkgdir(Ion, "test", "repos", "Comonicon"))
    @test project.name == "Comonicon"
    @test project.path == pkgdir(Ion, "test", "repos", "Comonicon")
    @test project.subdir == "."
    @test project.version.patch+1 == project.release_version.patch
    @test project.version_spec == "patch"
    @test project.branch == "master"

    print(stdin.buffer, 'y')
    project = Internal.ProjectToRelease("patch", pkgdir(Ion, "test", "repos", "Example"))
    readavailable(stdin.buffer)
    @test project.release_version == project.version
    @test Internal.should_update_version(project) == false

    project = Internal.ProjectToRelease("patch", pkgdir(Ion, "test", "repos", "Comonicon", "lib", "ComoniconTestUtils"); note="test note")
    @test project.subdir == "lib/ComoniconTestUtils"
    @test Internal.should_update_version(project) == true

    @test Internal.julia_registrator_comment(project) == """
    Released via [Ion](https://github.com/Roger-luo/Ion.jl)

    @JuliaRegistrator register branch=master subdir=lib/ComoniconTestUtils

    Patch notes:
    test note
    """

    project = Internal.ProjectToRelease("minor", pkgdir(Ion, "test", "repos", "Comonicon", "lib", "ComoniconTestUtils"); note="test note")
    @test Internal.julia_registrator_comment(project) == """
    Released via [Ion](https://github.com/Roger-luo/Ion.jl)

    @JuliaRegistrator register branch=master subdir=lib/ComoniconTestUtils

    Release notes:
    test note
    """

    project = Internal.ProjectToRelease("patch", pkgdir(Ion, "test", "repos", "PlutoSliderServer"))
    @test project.branch == "main"
    @test Internal.should_update_version(project) == true
end


Ion.release("patch", "Comonicon")
Ion.release("current", "../Comonicon")
project = Ion.Internal.ProjectToRelease("current", "../Comonicon")
