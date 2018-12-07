// controllers/usage.ts
// -------------------------------------------------------------------------------------------------
// Controller for the usage endpoint.
// -------------------------------------------------------------------------------------------------

import * as _ from 'lodash';
import * as P from 'bluebird';
import { Request, Response } from 'express';

import * as Validator from '../modules/validator';
import * as Google from '../modules/google';

// -------------------------------------------------------------------------------------------------
// Interfaces

export module Interfaces {

  export interface Hierarchy {
    id: string;
    token: string;
    secret: string;
  };

  export interface HierarchyUsage {
    id: string;
    usage: Google.Interfaces.UsageEntry[];
  };

};

// -------------------------------------------------------------------------------------------------
// Endpoints

/**
 * Get usage for all resellers in the `hierarchies` object.
 *
 * @param req - with JSON hierarchies structure in the GET params
 * @param res - just an express response
 * @return usage_response - Google reseller usage data for all companies in the `hierarchies`
 *                          variable.
 */
export const view = (req: Request, res: Response): P<Response> => {

  // Send the request to the validator and get the error message
  const validationErrorMessage = Validator.validate('GET /usage', req);

  // Check if the validation returned an error message
  if (validationErrorMessage.length !== 0) {

    // If the valdiation error message is not empty, make a helpful response with the validation
    // error in the response
    return P.resolve(
      res.json({
        id: 'error_validation',
        message: validationErrorMessage,
      }));

  }

  // Get the usage data for each hierarchy
  return P.mapSeries(JSON.parse(req.query.hierarchies), (hierarchy: Interfaces.Hierarchy) => {

    return Google.getUsage({
        client_id: hierarchy.id,
        client_secret: hierarchy.secret,
        refresh_token: hierarchy.token,
      }).then((usage: Google.Interfaces.UsageEntry[]) => ({
        id: hierarchy.id,
        usage,
      }));

  }).then((usages: Interfaces.HierarchyUsage[]) => {

    return res.json({
      id: 'success',
      data: usages
    });

  }).catch((error) => {

    console.log(error);

    return res.json({
      id: 'error_unknown',
      data: error
    });

  });

}