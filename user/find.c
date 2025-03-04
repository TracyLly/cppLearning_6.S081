#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "kernel/fs.h"
#include "kernel/stat.h"
#include "user/user.h"

/* 手动实现 strrchr() */
char *my_strrchr(const char *s, int c) {
    char *last = 0;
    while (*s) {
        if (*s == c)
            last = (char *)s;
        s++;
    }
    return last;
}

/* 获取路径中的文件名 */
char *basename(char *pathname) {
    char *last_slash = my_strrchr(pathname, '/');  // 使用 my_strrchr() 替代 strrchr()
    return (last_slash != 0) ? last_slash + 1 : pathname;
}

/* 手动实现 strncpy() */
void my_strncpy(char *dest, const char *src, int n) {
    int i;
    for (i = 0; i < n && src[i]; i++) {
        dest[i] = src[i];
    }
    while (i < n) {  // 填充 '\0'
        dest[i++] = '\0';
    }
}

/* 递归查找 */
void find(char *curr_path, char *target) {
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;

    if ((fd = open(curr_path, O_RDONLY)) < 0) {
        fprintf(2, "find: cannot open %s\n", curr_path);
        return;
    }

    if (fstat(fd, &st) < 0) {
        fprintf(2, "find: cannot stat %s\n", curr_path);
        close(fd);
        return;
    }

    switch (st.type) {
    case T_FILE: {
        char *f_name = basename(curr_path);
        if (strcmp(f_name, target) == 0) {
            printf("%s\n", curr_path);
        }
        close(fd);
        break;
    }

    case T_DIR:
        memset(buf, 0, sizeof(buf));
        uint curr_path_len = strlen(curr_path);
        memcpy(buf, curr_path, curr_path_len);
        buf[curr_path_len] = '/';
        p = buf + curr_path_len + 1;

        while (read(fd, &de, sizeof(de)) == sizeof(de)) {
            if (de.inum == 0 || strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0)
                continue;

            my_strncpy(p, de.name, DIRSIZ);  // 替换 strncpy()
            p[DIRSIZ] = '\0'; // 确保字符串终止

            find(buf, target);
        }
        close(fd);
        break;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(2, "usage: find [directory] [target filename]\n");
        exit(1);
    }
    find(argv[1], argv[2]);
    exit(0);
}
