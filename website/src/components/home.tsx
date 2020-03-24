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
        return (
            <div>
                <p>{state.isLogged ? "Plm" : "plt"}</p>
            </div>
        );
    };

    updateState = async (state: IState) => {
        return {...state, isLogged: app["token"]};
    };

    @on("#/") root = this.updateState;
}

export default new HomeComponent().mount("pain-app");
