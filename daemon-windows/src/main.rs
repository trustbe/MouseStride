mod name_gen;
mod distance_calc;
mod persistence;
mod dashboard;

#[cfg(windows)]
mod mouse_tracker;
#[cfg(windows)]
mod autostart;

fn main() {
    println!("MouseStride Windows daemon");
}
