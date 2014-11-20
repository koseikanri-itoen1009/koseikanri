/*============================================================================
* �t�@�C���� : XxcsoBmAccountInfoSummaryVOImpl
* �T�v����   : BM�ڋq���擾�r���[�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;

/*******************************************************************************
 * BM�ڋq���擾�r���[�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoBmAccountInfoSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoBmAccountInfoSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param bm1VendorCode    BM1���t��R�[�h
   * @param bm2VendorCode    BM2���t��R�[�h
   * @param bm3VendorCode    BM3���t��R�[�h
   * @param installAccountId �ݒu��ڋqID
   *****************************************************************************
   */
  public void initQuery(
    String bm1VendorCode
   ,String bm2VendorCode
   ,String bm3VendorCode
   ,Number installAccountId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int idx = 0;
    setWhereClauseParam(idx++, bm1VendorCode);
    setWhereClauseParam(idx++, bm2VendorCode);
    setWhereClauseParam(idx++, bm3VendorCode);
    setWhereClauseParam(idx++, bm1VendorCode);
    setWhereClauseParam(idx++, bm2VendorCode);
    setWhereClauseParam(idx++, bm3VendorCode);
    setWhereClauseParam(idx++, bm1VendorCode);
    setWhereClauseParam(idx++, bm2VendorCode);
    setWhereClauseParam(idx++, bm3VendorCode);
    setWhereClauseParam(idx++, installAccountId);

    executeQuery();
  }

}