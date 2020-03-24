import {fetchAsync} from "./fetch";

export interface ICredentials {
    name: string;
    password: string;
}

export const Auth = {
    login: (user: ICredentials) => fetchAsync("POST", "login", user),
    register: (user: ICredentials) => fetchAsync("POST", "register", user),
    refresh: () => fetchAsync("POST", "refresh"),
};
