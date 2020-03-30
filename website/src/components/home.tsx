import {app, Component, on} from "apprun";
import {IPainting} from "../models";
import {getImageLink} from "../fetch";

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
        const {paintings, isLogged} = state;
        if (isLogged) {
            let paintingBody = [];
            for (const painting of paintings) {
                paintingBody.push(
                    <tr>
                        <td>
                            <a href={getImageLink(painting.imagePath)}>View</a>
                        </td>
                        <td>{painting.name}</td>
                        <td>{painting.artist}</td>
                        <td>{new Date(painting.year).getFullYear()}</td>
                        <td>{painting.medium}</td>
                        <td>{new Date(painting.createdAt).toDateString()}</td>
                    </tr>
                );
            }

            const paintingsTable =
                paintings.length == 0 ? (
                    <p class="Cabin uk-text-medium">Your paintings will appear here..</p>
                ) : (
                    <table class="uk-table uk-table-hover uk-table-divider">
                        <thead>
                            <tr>
                                <th>Image</th>
                                <th>Name</th>
                                <th>Artist</th>
                                <th>Year</th>
                                <th>Medium</th>
                                <th>Created at</th>
                            </tr>
                        </thead>
                        <tbody>{paintingBody}</tbody>
                    </table>
                );
            return <div class="uk-flex uk-flex-center">{paintingsTable}</div>;
        }

        return (
            <div class="uk-position-center">
                <p class="Cabin uk-text-large">Experience museums like never before</p>
            </div>
        );
    };

    @on("#/") root = state => state;

    @on("/paintings-changed") changePaintings = (state, newPaintings) => ({...state, paintings: newPaintings});

    @on("/token-changed") tokenChanged = (state, token) => ({...state, isLogged: !!token});
}

export default new HomeComponent().mount("pain-app");
