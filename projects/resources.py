from tastypie.resources import ModelResource
from tastypie import fields
from tastypie.authentication import Authentication
from tastypie.authorization import Authorization
from push.base import sender
from .models import Project


class ProjectsAuthorization(Authorization):
    """Projects authorization"""

    def create_detail(self, object_list, bundle):
        return False

    def create_list(self, object_list, bundle):
        return False

    def delete_detail(self, object_list, bundle):
        return False

    def delete_list(self, object_list, bundle):
        return False

    def read_list(self, object_list, bundle):
        """Return only user resources"""
        if bundle.request.GET.get('fetch'):
            return Project.objects.get_or_create_for_user(bundle.request.user)
        else:
            return Project.objects.get_enabled_for_user(bundle.request.user)

    def read_detail(self, object_list, bundle):
        return bundle.obj.can_access(bundle.request.user)

    def update_list(self, object_list, bundle):
        return False

    def update_detail(self, object_list, bundle):
        sender.send(
            type='project', owner=bundle.request.user.id,
        )
        return bundle.obj.can_change(bundle.request.user)


class ProjectsResource(ModelResource):
    """Projects resource"""
    id = fields.CharField(attribute='id', readonly=True)
    name = fields.CharField(attribute='name', readonly=True)
    url = fields.CharField(attribute='url', readonly=True)
    is_private = fields.BooleanField(attribute='is_private', readonly=True)
    branches = fields.ListField(attribute='branches', readonly=True)
    icon = fields.CharField(attribute='icon', readonly=True, null=True)
    badge_url = fields.CharField(attribute='get_badge_url', readonly=True)
    owner_id = fields.CharField(attribute='owner_id', readonly=True)
    token = fields.CharField(attribute='token', blank=True, null=True)
    can_change = fields.BooleanField(default=False)

    class Meta:
        queryset = Project.objects.all()
        authentication = Authentication()
        authorization = ProjectsAuthorization()
        resource_name = 'projects/project'
        detail_uri_name = 'name'
        fields = (
            'name', 'is_enabled', 'id',
            'is_private', 'icon',
            'comment_from_owner_account',
        )

    def dehydrate(self, bundle):
        """Attach token to bundle if owner"""
        if (
            bundle.request.user.is_authenticated()
            and bundle.obj.can_change(bundle.request.user)
        ):
            bundle.data['can_change'] = True
        else:
            bundle.data['token'] = ''
        return bundle
