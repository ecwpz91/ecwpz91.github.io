FROM registry.access.redhat.com/rhscl/ruby-22-rhel7

MAINTAINER Michael Surbey "msurbey@redhat.com"

EXPOSE 4000

COPY . /opt/app-root/src

RUN /bin/bash -c 'bundle install'
RUN /bin/bash -c 'bundle exec jekyll build'

CMD /bin/bash -c 'bundle exec jekyll serve'
