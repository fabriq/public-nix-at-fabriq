# nix-at-fabriq

This repository is used to automatically configure the laptops used by engineers at Fabriq.

## Purpose

A usual pain in tech companies is setting up the devices of new hires with a development environment. Most often, engineers cobble up a setup script to automate this process, but this leads to two issues:

- The setup script often has flaws when run on a brand new machine, because of software updates and the inability of already-hired engineers to test the script from a clean state.
- The setup script will evolve according to desired changes of the development environments, but engineers that already ran the script on their devices will not benefit from the evolutions. Thus, development environments between engineers will drift, making some issues difficult to reproduce.

With Nix and Nix-darwin, we can declaratively define the state of the engineers' devices, thus ensuring that everyone has the same working development environment — now, and over time.

Once Nix is used to build reproducible development environments, it can be leveraged further. For example, we could:

- Remove Docker, as reproducibility and isolation can be achieved on the OS
- Build reproducible containers for deployment
- Make CI faster by caching dependencies more efficiently
- etc.

## Disclaimer

Nix and Nix-darwin are wonderful technologies, in that they enable a maximum level of automation and reproducibility, at least compared to all other technologies used for the same purpose. It is also somewhat lightweight, as there are no runtime costs to speak of — compared with something like Docker, which doesn't solve the problem as elegantly while causing performance and usability issues on macOS.

**However**, Nix and Nix-darwin are not user-friendly. Although Nix is a 20-year-old project and its main repository is among GitHub's most active ones, it is not mature enough for mainstream use. By relying on Nix at Fabriq, we exchange a set of issues for another set of issues: bugs, lack of documentation, frictions, etc.

This tradeoff has been made knowingly. For every minute wasted by some issue with Nix, know that you might have saved more than if we were still using a botched setup script.

## Setup

On any device:

- Clone the repository anywhere (but preferably in your home)
- Add in `data.json` the data relevant for you and your device (if it is missing)
- Run `./run bootstrap`
- Restart the terminal in which you ran the command above
- You're set!

## Usage

### Configuring your own device

You can create a file named `<hostname>.nix` in the folder `devices`, where `<hostname>` is the name of your device, and use it to configure your device to your liking. The file is a regular nix-darwin module, and therefore can be used to change anything on the system.

If you want to improve the organization with multiple files, you can instead create a folder named `<hostname>` in `devices`, with a file named `default.nix` as the entry point.

If you want to manage configuration specific to the main macOS user, you can define a home-manager module and import it in `fabriq.user.modules`. For example, if your module is the file `home.nix` at `devices/<hostname>`, you can add in `devices/<hostname>/default/nix` the following line:

```nix
  fabriq.home.modules = [ ./home.nix ];
```

Once your changes are committed, execute `./run rebuild` at the root of the repository to make them effective.

You can then submit a PR with your changes in order to save them remotely.

### Sharing system-level configuration

If you want to share some system-level configuration with other engineers at Fabriq, feel free to define a nix-darwin in `system_modules`. It will be automatically picked up. Expose an `enable` flag set to `false` by default so that engineers can opt-in themselves.

For configuration that should be enabled by default for everyone, set the flag to `true` in `common.nix`.

Commit the changes and submit a PR so that they are distributed.

### Sharing user-level configuration

If you want to share some user-level configuration with other engineers at Fabriq, feel free to define a home-manager module in `user_modules`. It will be automatically picked up. Expose an `enable` flag set to `false` by default so that engineers can opt-in themselves.

For configuration that should be enabled by default for everyone, set the flag to `true` in `common.nix`, inside the `userConfig` expression.

Commit the changes and submit a PR so that they are distributed.

## FAQ

### How do I update a package?

To understand how a package is to be updated, one needs to understand flakes and nixpkgs.

Flakes are a way to independently distribute packages with nix. When you want to add a package with nix that is distributed with flakes, you just need to add the URL to the flake in the inputs (or the shorthand to a GitHub repository). Nix will then update the lockfile to ensure the input stays consistent across rebuilds.

If you want to update the packages installed through flakes, you just have to refresh the lock file. The same URLs are now pointing to updated packages, so the lock file will change. If the new version of the package is distributed through another URL, you must first update the URL in the input, then rebuild. This is very similar to other package managers.

However, most Nix packages are not distributed through flakes. They are maintained in Nixpkgs, an enormous repositories with all the Nix code to build common packages. Nixpkgs largely predates flakes, but we use it like a flake. It is declared as an input, which then lets us install any packages from it. What will we be recorded in the lockfile is the version of Nixpkgs as a whole. This is why, to update a package from Nixpkgs, one must also regenerate the lockfile, but it is impossible to _selectively_ update a package from Nixpkgs. You update them all, or you update none of them.

A few common packages are distributed with multiple major versions in Nixpkgs (such as node, python, postgres), which gives better control when performing big updates.

### How can I set a specific version for a package?

If the package whose version you want to pin is distributed as a flake with GitHub, you can specify a revision that must be followed directly in the input. This will effectively pin the package, even when rebuilding the lockfile.

If the package whose version you want to pin is distributed through Nixpkgs, you're out of luck. You cannot pin it without pinning the entirety of Nixpkgs.

### How can I setup project-specific environments?

This should be done locally on each repository. For now, at Fabriq, we do not use project-specific environments (but this will come!).

### How can I uninstall a package?

You just have to remove the Nix code that adds it to the system, and then rebuild the system with `./run rebuild`. Nix is declarative: the state of the device will reflect what is in the code.
