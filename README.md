![typing](https://readme-typing-svg.demolab.com?font=Fira+Code&pause=500&color=d82b00&width=435&lines=Usurper,;buidling+one+lab+at+a+time)

A lab lifecycle manager for disposable VMs. Usurper installs, inspects, and tears down self-contained labs so a single box can be reused as a clean training ground.

> [!WARNING]
> Labs may be **deliberately vulnerable**. Only run Usurper on an isolated, disposable VM you control.

## How it works

Each lab is a self-contained directory under `labs/`. Adding a lab means dropping in a directory — there's no central file to edit. Only one lab may be active at a time.

```
/opt/usurper/
└── labs/
    ├── registry          # one lab name per line (# comments ok)
    └── <lab-name>/
        ├── install.sh     # stand the lab up
        ├── remove.sh      # tear it down
        └── details.txt    # human-readable notes
```

## Usage

All commands require `sudo`

```
sudo usurper list                list available labs (active one marked *)
sudo usurper check               show the active lab
sudo usurper details <lab>       show details about a lab
sudo usurper install <lab>       install and activate a lab
sudo usurper remove  <lab>       tear down and deactivate the active lab
```

A lab is only marked active once its `install.sh` succeeds, and left active if `remove.sh` fails.

## Configuration

Set via environment variables:

| Variable       | Default         | Description              |
| -------------- | --------------- | ------------------------ |
| `USURPER_HOME` | `/opt/usurper`  | Base directory for labs  |
