import {app, Component, on} from "apprun";
import {setToken} from "../fetch";

class HeaderComponent extends Component {
    state = {};

    view = state => {
        const {token} = state;
        return (
            <nav class="uk-navbar-container" uk-navbar>
                <div class="uk-navbar-left">
                    <a class="uk-navbar-item uk-logo" href="#">
                        Pain
                    </a>
                    {token && <a class="uk-navbar-item uk-icon" uk-icon="icon: upload" href="#/upload-painting" />}
                    <a class="uk-navbar-item" onclick={e => this.run("credentials", e)}>
                        {!token ? "Login" : "Logout"}
                    </a>
                </div>
            </nav>
        );
    };

    @on("credentials") credentials = (state, e) => {
        e.preventDefault();
        if (state.token) {
            document.cookie.split(";").forEach(c => {
                document.cookie = c
                    .replace(/^ +/, "")
                    .replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
            });
            setToken(null);
            location.reload();
        } else {
            this.run("#/login");
        }
    };

    @on("/token-changed") tokenChanged = (state, token) => {
        return {...state, token: token};
    };
}

export default new HeaderComponent().start("header");
