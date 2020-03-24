export type IUser = string;

export interface IPainting {
    id: number;
    name: string;
    artist: string;
    year: Date;
    medium: string;
    createdAt: Date;
    description: string;
    imagePath: string;
    hits: number;
}
