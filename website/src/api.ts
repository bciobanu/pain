import app from "apprun";

import {fetchAsync, setToken} from "./fetch";
import {IPainting} from "./models";

export interface ICredentials {
    name: string;
    password: string;
}

export interface IPaintingsResponse extends IPainting {
    userName: string;
}

export const Auth = {
    login: (user: ICredentials) => fetchAsync("POST", "login", user),
    register: (user: ICredentials) => fetchAsync("POST", "register", user),
    refresh: () =>
        fetchAsync("POST", "refresh")
            .then(r => r["Value"])
            .then(setToken),
};

export const Paintings = {
    list: () =>
        fetchAsync("GET", "paintings").then(paintings => {
            const newPaintings: Array<IPainting> = [];
            for (const painting of paintings) {
                const newPainting: IPainting = {
                    id: painting["ID"],
                    name: painting["Name"],
                    artist: painting["Artist"],
                    year: painting["Year"],
                    medium: painting["Medium"],
                    createdAt: painting["CreatedAt"],
                    description: painting["Description"],
                    imagePath: painting["ImagePath"],
                    hits: 0,
                };
                newPaintings.push(newPainting);
            }

            if (JSON.stringify(app["paintings"]) !== JSON.stringify(newPaintings)) {
                app["paintings"] = newPaintings;
                app.run("/paintings-changed", newPaintings);
            }
        }),
};

app.on("/refresh", () => Promise.all([Auth.refresh(), Paintings.list()]));
