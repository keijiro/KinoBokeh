use std::env;
use std::f32::{self, consts};

fn main() {
    let mut args = env::args();
    let arg1 = args.nth(1).unwrap_or(String::new()).parse::<u32>();
    let arg2 = args.nth(0).unwrap_or(String::new()).parse::<u32>();

    if arg1.is_err() || arg2.is_err() {
        println!("Usage: bokeh_kernel number_of_rings points_per_ring");
        return;
    }

    let rings = arg1.unwrap();
    let points_per_ring = arg2.unwrap();

    let total_points = (0..rings).fold(0, |acc, i| acc + i) * points_per_ring;

    println!("static const int kSampleCount = {};", total_points + 1);
    println!("static const float2 kDiskKernel[kSampleCount] = {{");
    println!("    float2(0,0),");

    for ring in 1..rings {
        let bias = 1.0 / (points_per_ring as f32);
        let radius = ((ring as f32) + bias) / ((rings as f32) + bias);
        let points = ring * points_per_ring;
        for pt in 0..points {
            let phi = 2.0 * consts::PI * (pt as f32) / (points as f32);
            let x = phi.cos() * radius;
            let y = phi.sin() * radius;
            println!("    float2({},{}),", x, y);
        }
    }

    println!("}};");
}
