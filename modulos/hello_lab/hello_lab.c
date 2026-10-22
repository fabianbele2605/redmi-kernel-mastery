// SPDX-License-Identifier: GPL-2.0
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init hello_lab_init(void)
{
	pr_info("hello_lab: hola desde el kernel del Redmi Note 11\n");
	return 0;
}

static void __exit hello_lab_exit(void)
{
	pr_info("hello_lab: adios\n");
}

module_init(hello_lab_init);
module_exit(hello_lab_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("fabian");
MODULE_DESCRIPTION("Laboratorio: primer modulo");
