import type { components } from '../generated/demo/api-types'

export type Party = components['schemas']['_Party']
export type Iou = components['schemas']['Iou']
export type IouList = components['schemas']['Iou_List']
export type IouCreate = components['schemas']['Iou_Create']
export type IouStates = components['schemas']['Iou_States']
export type IouPayCommand = components['schemas']['Iou_Pay_Command']
export type TimestampedAmount = components['schemas']['TimestampedAmount']

export function partyFromEmail(email: string): Party {
  return {
    claims: {
      email: [email]
    }
  }
}

export function getPartyEmail(party: Party): string {
  return party.claims.email?.[0] || party.claims.preferred_username?.[0] || 'unknown'
}
