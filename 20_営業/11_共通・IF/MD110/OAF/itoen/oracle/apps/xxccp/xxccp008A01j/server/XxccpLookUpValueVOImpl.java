/*============================================================================
* �t�@�C���� : XxccpLookUpValueVOImpl.java
* �T�v����   : �Q�ƃ^�C�v�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-13 1.0  SCS KUME     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp008A01j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �Q�ƃ^�C�v�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  SCS KUME
 * @version 1.0
 ***************************************************************************
 */
public class XxccpLookUpValueVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxccpLookUpValueVOImpl()
  {
  }

  /**
   * �Q�ƃ^�C�v���擾����B
   * @param lookuptype ���b�N�A�b�v�^�C�v
   * @param conType �R�[�h
   */
  public void getLookUpValue(String lookuptype, String conType)
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, lookuptype);
    setWhereClauseParam(1, conType);
    executeQuery();
  }
}