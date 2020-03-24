import {fetchAsync} from "./fetch";

export const Auth = {
    login: (user: {name: string; password: string}) => {
        fetchAsync("POST", "login", user).then(console.log);
    },
};
