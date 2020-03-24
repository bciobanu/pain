import app from "apprun";
import {Auth} from "./api";

app.on("#", (route, ...p) => {
    app.run(`#/${route || ""}`, ...p);
});

Auth.login({name: "bob", password: "zilla"});

//app.run("/get-user");
