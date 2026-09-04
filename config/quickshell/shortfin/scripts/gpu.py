"""Report integrated-GPU busyness, for machines whose desktop is not on the
discrete card.

nvidia-smi answers for the NVIDIA GPU, but on a hybrid laptop that card sits
at 0% until something is explicitly offloaded to it -- the compositor and the
browser are on the integrated one. Open-source DRM drivers publish per-client
engine time in fdinfo (the same source nvtop and btop read), so the busyness
is the sum of that across every client, per unit of wall time.

Prints: IGPU <cumulative busy ns> <current clock MHz> <driver>
The caller turns consecutive samples into a percentage, and uses the driver
name to say whose GPU it is rather than assuming a vendor.
"""

import glob

SKIP_DRIVERS = ("nvidia",)

def busy_nanoseconds():

    clients = {}
    driver = ""

    for fdinfo in glob.glob("/proc/[0-9]*/fdinfo/*"):
        try:
            with open(fdinfo) as handle:
                data = handle.read()
        except OSError:

            continue

        if "drm-client-id" not in data:
            continue

        client = None
        busy = 0
        skip = False
        found = ""

        for line in data.splitlines():
            key, _, value = line.partition(":")
            value = value.strip()

            if key == "drm-driver":
                skip = value in SKIP_DRIVERS
                found = value
            elif key == "drm-client-id":
                client = value
            elif key.startswith("drm-engine-") and not key.startswith("drm-engine-capacity"):
                busy += int(value.split()[0])

        if skip or client is None:
            continue

        clients[client] = max(clients.get(client, 0), busy)
        driver = driver or found

    return sum(clients.values()), driver

def clock_mhz():

    for name in ("gt_cur_freq_mhz", "gt_act_freq_mhz"):
        for path in sorted(glob.glob(f"/sys/class/drm/card*/{name}")):
            try:
                with open(path) as handle:
                    value = int(handle.read().strip())
            except (OSError, ValueError):
                continue

            if value > 0:
                return value

    for path in sorted(glob.glob("/sys/class/drm/card*/device/pp_dpm_sclk")):
        try:
            with open(path) as handle:
                table = handle.read()
        except OSError:
            continue

        for line in table.splitlines():
            if not line.rstrip().endswith("*"):
                continue
            for token in line.split():
                digits = token.rstrip("Mmhz")
                if digits.isdigit():
                    return int(digits)

    return 0

busy, driver = busy_nanoseconds()
print("IGPU", busy, clock_mhz(), driver or "-")
