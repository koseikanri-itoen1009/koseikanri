/*============================================================================
* �t�@�C���� : XxpoProvisionRtnMakeLineVOImpl
* �T�v����   : �x���ԕi�쐬���׃r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  �F�{�a�Y     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �x���ԕi�쐬���׃r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeLineVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnMakeLineVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param exeType       - �N���^�C�v ���x���ԕi�ł͖��g�p
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   ****************************************************************************/
  public void initQuery(
    String exeType,
    Number orderHeaderId
  )
  {
    int i = 0;
    setWhereClauseParam(i, orderHeaderId);
    // �������s
    executeQuery();
  }
}