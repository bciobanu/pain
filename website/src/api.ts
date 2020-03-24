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
    list: () => fetchAsync("GET", "paintings"),
};

app.on("/refresh", Auth.refresh);
