import {app, Component, on} from "apprun";
import {Auth} from "../api";
import {serializeObject} from "../fetch";

class LoginComponent extends Component {
    state = {};

    goBack = state => {
        const returnTo: string = (state.returnTo || "").replace(/\#\/register\/?/, "");
        if (!returnTo) {
            document.location.hash = "#/";
        } else {
            app.run("route", returnTo);
            history.pushState(null, null, returnTo);
        }
    };

    view = state => {
        return (
            <div id="login" class="uk-flex uk-flex-center">
                <form onsubmit={e => this.run("auth", e)}>
                    <div class="uk-margin">
                        <div class="uk-inline">
                            <span class="uk-form-icon" uk-icon="icon: user"></span>
                            <input name="name" class="uk-input" type="text" />
                        </div>
                    </div>

                    <div class="uk-margin">
                        <div class="uk-inline">
                            <span class="uk-form-icon" uk-icon="icon: lock"></span>
                            <input name="password" class="uk-input" type="password" />
                        </div>
                    </div>

                    <button class="uk-button uk-button-default uk-width-expand">Log in</button>
                </form>
            </div>
        );
    };

    @on("#/login") login = state => state;

    @on("auth") auth = async (state, e) => {
        try {
            e.preventDefault();

            await Auth.login(serializeObject(e.target));
            await Auth.refresh();
            this.goBack(state);
        } catch ({errors}) {
            return {...state, errors};
        }
    };
}

export default new LoginComponent().mount("pain-app");
