The building and packaging process is somewhat convoluted, it has 3 basic steps:

1. Generate and upload source package to github release page

2. Build conda packages and upload to [anaconda repo](https://anaconda.org/AstoCAD/freecad)

3. Generate bundles from the above conda package and all it's dependencies and upload to github release page

---
## Step 1
this happens at [FreeCAD-Bundle's source_creation.yml](https://github.com/AstoCAD/FreeCAD-Bundle/actions/workflows/source_creation.yml), weekly builds are made with the action as defined in the main branch of this repo.

For each stable release a separate branch should be created, the config of the action should be adapted for the release:
[source_creation.yml#L17-L18](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/.github/workflows/source_creation.yml#L17-L18)

Where:
+ `branch`: is the source git ref from which the source package will be generated. This probably should be renamed to gitRef as it can either be a branch tag or commit.
+ `tag`: is the target tag on the https://github.com/AstoCAD/FreeCAD repo where the source package will be uploaded, if the tag doesn't exist it will be created at the branch/git ref provided

This action is configured to run daily: [source_creation.yml#L8](https://github.com/AstoCAD/FreeCAD-Bundle/blob/main/.github/workflows/source_creation.yml#L8)

---

## Step 2
this happens at [astocad-feedstock](https://github.com/AstoCAD/astocad-feedstock). The builds happen any time a commit is pushed to the repo however the built package only gets uploaded to anaconda if the version number or build number has been increased since the last upload to anaconda so for the weekly builds a simple github action that increases the build number is scheduled some minutes after Step 1's schedule: [increase_build_number.yml#L4](https://github.com/AstoCAD/astocad-feedstock/blob/68b1a6f2767ddbced35991a5a6848c61121e0309/.github/workflows/increase_build_number.yml#L4)

This is likely the most complex to manage part of the process as it's heavily reliant on  conda-forge's packages and building tools, more documentation on managing this can be found at https://conda-forge.org/docs/maintainer/, some relevant tools that are worth getting to know for this are `conda`, `conda-smithy`, `conda-build`

These are some of the most relevant files in the repo:
[meta.yaml](https://github.com/AstoCAD/astocad-feedstock/blob/main/recipe/meta.yaml)
[build.sh](https://github.com/AstoCAD/astocad-feedstock/blob/main/recipe/build.sh)
[bld.bat](https://github.com/AstoCAD/astocad-feedstock/blob/main/recipe/bld.bat)

Same as with Step 1 the weekly-builds happen at main branch of the repo and each stable release should have a separate branch, in said separate branches it's imporant to set the correct version number and source url:
[meta.yaml#L2-L3](https://github.com/AstoCAD/astocad-feedstock/blob/68b1a6f2767ddbced35991a5a6848c61121e0309/recipe/meta.yaml#L2-L3),
[meta.yaml#L11](https://github.com/AstoCAD/astocad-feedstock/blob/68b1a6f2767ddbced35991a5a6848c61121e0309/recipe/meta.yaml#L11)

for our distribution we only build for one python version:
[meta.yaml#L22](https://github.com/AstoCAD/astocad-feedstock/blob/68b1a6f2767ddbced35991a5a6848c61121e0309/recipe/meta.yaml#L22)

These builds are made cleanly with no caching and github's runners are relatively weak so they take time.

---

## Step 3
Finally, this happens at FreeCAD-Bundle's [freecad_bundle.yml](https://github.com/AstoCAD/FreeCAD-Bundle/actions/workflows/freecad_bundle.yml) and [.cirrus.yml](https://cirrus-ci.com/github/AstoCAD/FreeCAD-Bundle/main), most bundles are made with github actions except linux aarch64 which are made with cirrus CI. In the conda directory of this repo there are directories for each OS with the corresponding script `create_bundle.{sh,bat}` and the files they need. The scripts need conda/mamba to function, they essentially create a conda environment with the desired freecad/astocad package and all dependencies and extra packages desired, clean up some junk, make some adaptations, install extra addons (as defined in conda/build/script/install_addons.py) and then compress all of it in the corresponding format for the OS .AppImage, .dmg or .7z.

The weekly builds are scheduled a few hours after Step 2 to make sure they are finished before the bundling happens as otherwise the previous package would just be re-bundled. [freecad_bundle.yml#L4](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/.github/workflows/freecad_bundle.yml#L4)

In the branches for the stable releases it's important to point this action to the right tag: [freecad_bundle.yml#L21](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/.github/workflows/freecad_bundle.yml#L21), [.cirrus.yml#L2](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/.cirrus.yml#L2) and the bundle scripts to the right conda package version: [win/create_bundle.bat#L8](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/conda/win/create_bundle.bat#L8), [linux/create_bundle.sh#L11](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/conda/linux/create_bundle.sh#L11), [osx/create_bundle.sh#L10](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/conda/osx/create_bundle.sh#L10)

And the right conda channel: [osx/create_bundle.sh#L21](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/conda/osx/create_bundle.sh#L16), [linux/create_bundle.sh#L21](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/conda/linux/create_bundle.sh#L21), [win/create_bundle.bat#L15-L17](https://github.com/AstoCAD/FreeCAD-Bundle/blob/66ba52b384642c452397f5b2436b074f4fb11492/conda/win/create_bundle.bat#L15-L17)

---

For a stable release here are some good reference commits to create new branches for the release:
[freecad-feedstock@3ad9ab4a0](https://github.com/FreeCAD/freecad-feedstock/commit/3ad9ab4a06afc1fa2f70267f5a40d9c316d5eeac)
[FreeCAD-Bundle@080c204ae](https://github.com/FreeCAD/FreeCAD-Bundle/commit/080c204aed4d5155924d471b8ac2b07fad22acf1)

---

### Simplified steps to make a new weekly build:
1. go to https://github.com/FreeCAD/FreeCAD-Bundle/actions/workflows/source_creation.yml and click `Run workflow` -> `Run workflow` and a new run will appear after some seconds in the list, once that is finished (green checkmark);

2. go to https://github.com/AstoCAD/astocad-feedstock/actions/workflows/increase_build_number.yml and run the workflow, the workflow will be done quickly but this only creates a commit in the repo to start new builds. You can monitor the builds at https://github.com/AstoCAD/astocad-feedstock/actions/workflows/conda-build.yml or in the tick that appears on the newly created commit. The build will take a few hours, usually linux aarch64 and macos intel builds take the longest ~2.5h. Once all builds are done;

3. go to https://github.com/AstoCAD/FreeCAD-Bundle/actions/workflows/freecad_bundle.yml and run the workflow and also go to https://cirrus-ci.com/github/AstoCAD/FreeCAD-Bundle/main and click the `+` button. In a few minutes new bundles will be uploaded to the github release page.


---

### Possible future improvements:
+ github is supposed to eventually offer aarch64 linux runners too, once that happens all builds and bundles could be moved to github. It might also be possible to emulate for bundling.
+ windows bundles could be made into actual installers, this will be good for uptream FreeCAD but due to signing requirement might be useless to us
+ It might be possible to create a single github action that runs all 3 steps outlined above in sequence so that it's easier to manage.