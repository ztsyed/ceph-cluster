FROM ceph-base:git-

#EXPOSE 6789
ENTRYPOINT ["/app/bin/boot"]
ADD bin/boot /app/bin/boot

CMD ["ceph-mon"]
