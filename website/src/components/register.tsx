import {app, Component, on} from "apprun";
import {Auth} from "../api";
import {getToken, serializeObject} from "../fetch";

class RegisterComponent extends Component {
    state = {};

    goBack = state => {
        const returnTo: string = (state.returnTo || "").replace(/\#\/register\/?/, "");
        if (!returnTo) {
            document.location.hash = "#/";
        } else {
            app.run("route", returnTo);
            history.pushState(null, null, returnTo);
        }
    }

    view = state => {
        return (
            <div class="uk-flex uk-flex-center">
                <form onsubmit={e => this.run("register", e)}>
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

                    <button class="uk-button uk-button-default uk-width-expand">Register</button>
                </form>
            </div>
        );
    };

    @on("#/register") register = state => state;

    @on("register") auth = async (state, e) => {
        try {
            e.preventDefault();

            await Auth.register(serializeObject(e.target));
            await Auth.refresh();
            this.goBack(state);
        } catch ({errors}) {
            console.log(errors);
            return {...state, errors};
        }
    };
}

export default new RegisterComponent().mount("pain-app");
