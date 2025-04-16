import click

@click.group()
def app():
    pass

@click.command()
@click.argument("vodml")
def schema(vodml):
    click.echo(f'generating schema for {vodml}')

# TODO add more commands similar to the gradle tooling.
if __name__ == '__main__':
    app()
