import app from "apprun";
import {Auth} from "./api";

app.on("#", (route, ...p) => {
    app.run(`#/${route || ""}`, ...p);
});

Auth.login({name: "bob", password: "zilla"});
Auth.refresh().then(console.log);

//app.run("/get-user");
