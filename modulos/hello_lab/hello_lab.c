// SPDX-License-Identifier: GPL-2.0
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>

static struct proc_dir_entry *hello_ent;
static unsigned long lecturas;

static int hello_show(struct seq_file *m, void *v)
{
	lecturas++;
	seq_puts(m, "hola desde el kernel del Redmi Note 11\n");
	seq_printf(m, "lecturas: %lu\n", lecturas);
	return 0;
}

static int hello_open(struct inode *inode, struct file *file)
{
	return single_open(file, hello_show, NULL);
}

static const struct file_operations hello_fops = {
	.owner 		= THIS_MODULE,
	.open		= hello_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int __init hello_lab_init(void)
{
		 hello_ent = proc_create("hello_lab", 0444, NULL, &hello_fops);
		 if (!hello_ent)
		 		  return -ENOMEM;
		 pr_info("hello_lab: cargado, nodo /proc/hello_lab creado\n");
		 return 0;
}

static void __exit hello_lab_exit(void)
{
	proc_remove(hello_ent);
	pr_info("hello_lab: descargado, nodo /proc/hello_lab eliminado\n");
}

module_init(hello_lab_init);
module_exit(hello_lab_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("fabian");
MODULE_DESCRIPTION("Laboratorio: nodo /proc de solo lectura");
