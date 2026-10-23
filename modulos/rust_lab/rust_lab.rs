// SPDX-License-Identifier: GPL-2.0

//! Rust minimal sample.

use kernel::prelude::*;

module! {
    type: RustLab,
    name: "rust_lab",
    authors: ["Fabian Beleno"],
    description: "Laboratorio: buffer en Rust",
    license: "GPL",
}

struct RustLab {
    numbers: KVec<i32>,
}

impl kernel::Module for RustLab {
    fn init(_module: &'static ThisModule) -> Result<Self> {
        pr_info!("Rust Lab sample (init)\n");
        pr_info!("Am I built-in? {}\n", !cfg!(MODULE));

        let mut numbers = KVec::new();
        for i in 0..5 {
            numbers.push(i * 10, GFP_KERNEL)?;
        }
        let mut total = 0;
        for n in numbers.iter() {
            total += *n;
        }
        pr_info!("suma: {}\n", total);
        pr_info!("numeros {:?}\n", numbers);

        Ok(RustLab { numbers })
    }
}

impl Drop for RustLab {
    fn drop(&mut self) {
        pr_info!("My numbers are {:?}\n", self.numbers);
        pr_info!("Rust Lab sample (exit)\n");
    }
}
