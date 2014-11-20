/*============================================================================
* �t�@�C���� : XxpoProvisionRtnMakeTotalVOImpl
* �T�v����   : �x���ԕi�쐬���v�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-02 1.0  �F�{�a�Y     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.server;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * �x���ԕi�쐬���v�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvisionRtnMakeTotalVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param orderHeaderId - �󒍃w�b�_�A�h�I��ID
   ****************************************************************************/
  public void initQuery(Number orderHeaderId)
  {
    // �����ݒ�
    setWhereClauseParam(0, orderHeaderId);

    // �������s
    executeQuery();

  }


}