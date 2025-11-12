# Police Missions Script for QBCore

A comprehensive police mission system for QBCore FiveM servers that creates dynamic scenarios for law enforcement roleplay. I used it in my server for a while

## Features

- **5 Different Mission Types**: Fleeca Robbery, Stab City Raid, Weapon Deal, Paleto Bank Robbery, and Prison Break
- **Automatic Mission Generation**: Missions spawn automatically every 30 minutes when enough officers are on duty
- **Manual Mission Control**: Commands for starting specific or random missions
- **Hostage Rescue**: Free hostages to complete hostage-based missions
- **Vehicle Recovery**: Deliver stolen vehicles in weapon deal missions
- **Dynamic NPCs**: Armed criminals and hostages with appropriate behaviors
- **QB-Target Integration**: Interactive elements for mission completion
- **Police Job Restriction**: Only accessible to on-duty police officers
- **Admin Controls**: Administrative commands for mission management

## Installation

1. Add this resource to your `resources` directory
2. Ensure `qb-core` and `qb-target` are installed and running
3. Add `ensure police_missions` to your `server.cfg`

## Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-target](https://github.com/qbcore-framework/qb-target)

## Configuration

### Mission Types

1. **Fleeca Robbery**: Hostage situation at Fleeca Bank
2. **Stab City Raid**: Raid on Stab City with multiple hostages
3. **Weapon Deal**: Large-scale weapons deal with vehicle recovery
4. **Paleto Bank Robbery**: Bank robbery at Paleto Bay
5. **Prison Break**: Prison infiltration attempt

### Automatic Spawning

- Missions automatically spawn every 30 minutes
- Requires minimum of 2 police officers on duty
- Random mission selection

## Commands

### Police Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/startmission` | Start a random police mission | `/startmission` |
| `/startmissionid [id]` | Start specific mission by ID (1-5) | `/startmissionid 2` |
| `/listmissions` | List all available missions | `/listmissions` |
| `/missionstatus` | Check current mission status | `/missionstatus` |

### Admin Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/adminstartmission [id/random]` | Admin: Start any mission | `/adminstartmission 3` or `/adminstartmission random` |
| `/clearmission` | Clear active mission | `/clearmission` |

## Mission Completion

### Hostage Missions
- Use QB-Target on hostages and select "Free Hostage"
- Complete the progress bar to rescue the hostage
- All hostages must be freed to complete the mission

### Vehicle Missions
- Use QB-Target on the mission vehicle and select "Deliver Car"
- Complete the progress bar to deliver the vehicle
- Vehicle will be removed and mission completed


## Customization

### Adding New Missions

Edit the `Missions` table in `server.lua`:

```lua
[6] = {
    name = "New Mission Name",
    notification = "Alert message for police",
    criminals = {
        {coords = vector4(x, y, z, heading)},
        -- Add more criminal positions
    },
    hostages = {
        {coords = vector4(x, y, z, heading)},
        -- Add hostage positions (optional)
    },
    vehicle = {
        coords = vector4(x, y, z, heading),
        model = "vehicle_model"
    }, -- (optional)
    blipCoords = vector3(x, y, z),
    type = "hostage" -- or "vehicle"
}```
