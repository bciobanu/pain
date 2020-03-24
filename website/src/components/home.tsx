import {app, Component, on, customElement} from "apprun";
import {IPainting} from "../models";

declare interface IState {
    paintings: Array<IPainting>,
    isLogged: boolean,
};

@customElement("pain-home")
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
        )
    };

    updateState = async(state) => {
        return {...state, isLogged: app["token"]};
    }

    @on('#/') root = async (state) => await this.updateState(state);
};

export default new HomeComponent().mount("pain-app");
