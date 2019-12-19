import logger from "../common/logger";
import xmlmc from "./xmlmc";
import url from 'url';
import querystring from 'querystring';

export default async req => {
  return !!(
    req.method === "HEAD" ||
    req.header("x-original-uri").match(/^\/[_.].*/) ||
    embedOnly(req) ||
    requestWithinLimit(req) ||
    (await fromSw(req))
  );
};

async function fromSw(req) {
  const sessid = req.header("referer").match(/sessid=[a-zA-Z0-9]+/);
  if (sessid) {
    const id = sessid.split("=")[1];
    try {
      await xmlmc.session.isSessionValid({ sessionId: id }).params;
      return true;
    } catch (e) {
      return false;
    }
  }
}

function requestWithinLimit(req) {
  // allow requests within an hour of each other without re-authentication
  if (req.session && req.session.lastauthdate) {
    logger.debug(
      `time since last auth : ${(now() - req.session.lastauthdate) /
        1000 /
        60 /
        60}`
    );
    return now() - req.session.lastauthdate < 60 * 60 * 1000;
  }
}

function now() {
  const date = new Date();
  return date.getTime();
}

// toggle embedOnly in the session on and off. This allows us to bypass authentication for iframes
function embedOnly(req) {
  logger.debug('Checking for embed flag')
  if(req.session.embedOnly) {
    if(!req.header('X-SW-TOKEN') && !req.session.sessid) {
      return true;
    } else {
      req.session.embedOnly = false;
    }
  }
  const parsedArgs = querystring.parse(url.parse(req.header('x-original-uri')));
  if(parsedArgs.embed) {
    req.session.embedOnly = true;
    return true;
  }

  return false;
}
