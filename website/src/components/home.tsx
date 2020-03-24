import {app, Component, on} from "apprun";
import {IPainting} from "../models";

declare interface IState {
    paintings: Array<IPainting>;
    isLogged: boolean;
}

class HomeComponent extends Component {
    state: IState = {
        paintings: [],
        isLogged: false,
    };

    view = state => {
        const {isLogged} = state;
        if (isLogged) {
            return (
                <div>
                    <p>Mare boss</p>
                </div>
            );
        }

        return (
            <div class="uk-position-center">
                <p class="Cabin uk-text-large">Experience museums like never before</p>
            </div>
        );
    }

    @on("#/") root = state => state;
   
    @on("/token-changed") tokenChanged = (state, token) => ({...state, isLogged: !!token});
}

export default new HomeComponent().mount("pain-app");
