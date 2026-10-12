(async()=>{
 let snapshot,health;
 try {
  const responses=await Promise.all([
   fetch('/release-tracker.json',{cache:'no-store'}),
   fetch('/release-tracker/health.json',{cache:'no-store'})
  ]);
  if(responses.some(response=>!response.ok))throw new Error('Release metadata unavailable');
  [snapshot,health]=await Promise.all(responses.map(response=>response.json()));
  if(snapshot.schema_version!==1||!Array.isArray(snapshot.repositories))throw new Error('Release metadata schema unavailable');
 }catch(error){snapshot=null;health=null;}
 const elements=document.querySelectorAll('[data-release-freshness]');
 if(!snapshot||!health){elements.forEach(el=>el.textContent='The last complete snapshot is available from the source links. Freshness information is unavailable.');return;}
 const hasMatchingIdentity=snapshot.content_sha256===health.content_sha256;
 const elapsed=Date.now()-Date.parse(health.checked_at);
 const isFresh=hasMatchingIdentity&&Number.isFinite(elapsed)&&elapsed>=-300000&&elapsed<2*60*60*1000;
 const status=isFresh?'Last successful check: ':'Snapshot needs a fresh check. Last successful check: ';
 elements.forEach(el=>{el.textContent=status+new Date(health.checked_at).toLocaleString()+' · '+health.repository_count+' repositories';el.dataset.fresh=isFresh?'true':'false';});
 function addText(parent,tag,text,className){const node=document.createElement(tag);node.textContent=text;if(className)node.className=className;parent.append(node);return node;}
 function addLink(parent,title,url){const node=addText(parent,'a',title);node.href=url;return node;}
 function dateLabel(value){return new Date(value).toLocaleDateString(undefined,{year:'numeric',month:'short',day:'numeric'});}
 const table=document.getElementById('release-repositories');
 const summary=document.getElementById('release-summary');
 if(table)for(const repository of snapshot.repositories){
  const row=document.createElement('tr');const project=document.createElement('td');addLink(project,repository.project_title,repository.repository_url);row.append(project);
  const published=document.createElement('td');const latest=repository.list_of_releases[0];
  if(latest){addLink(published,latest.tag_name,latest.release_url);addText(published,'span',latest.is_prerelease?'Published prerelease':'Published release','state');const disclosure=document.createElement('details');addText(disclosure,'summary','Exact release identity');addText(disclosure,'p',latest.source_commit,'identity');for(const asset of latest.list_of_assets){addLink(disclosure,asset.asset_title,asset.download_url);addText(disclosure,'p',asset.github_reported_digest||'Artifact digest not supplied by GitHub','identity');}published.append(disclosure);}
  else if(repository.latest_tag){addLink(published,repository.latest_tag,repository.repository_url+'/tree/'+repository.latest_tag_commit);addText(published,'span','Tagged source · no published GitHub release','state');}
  else addText(published,'span','Source only · no published GitHub release','state');row.append(published);
  const source=document.createElement('td');addLink(source,repository.source_commit.slice(0,10),repository.repository_url+'/commit/'+repository.source_commit);addText(source,'span',repository.tracked_branch+' · '+dateLabel(repository.source_updated_at),'state');if(repository.is_archived)addText(source,'span','Archived repository','state');row.append(source);
  const time=document.createElement('td');addText(time,'span',latest?dateLabel(latest.published_at):'—');row.append(time);table.append(row);
 }
 const events=snapshot.repositories.flatMap(repository=>repository.list_of_releases.map(release=>({repository,release}))).sort((a,b)=>b.release.published_at.localeCompare(a.release.published_at));
 const list=document.getElementById('release-events');
 if(list)for(const {repository,release} of events.slice(0,18)){const row=document.createElement('li');row.className='event';const time=addText(row,'time',dateLabel(release.published_at));time.dateTime=release.published_at;const detail=document.createElement('div');addLink(detail,repository.project_title+' · '+release.tag_name,release.release_url);addText(detail,'p',release.release_title);addText(detail,'p',(release.is_prerelease?'Published prerelease':'Published release')+' · '+release.source_commit.slice(0,10),'note');row.append(detail);list.append(row);}
 if(summary){for(const {repository,release} of events.slice(0,4)){const paragraph=document.createElement('p');addLink(paragraph,repository.project_title+' '+release.tag_name,release.release_url);addText(paragraph,'span',' · '+dateLabel(release.published_at));summary.append(paragraph);}}
})();
