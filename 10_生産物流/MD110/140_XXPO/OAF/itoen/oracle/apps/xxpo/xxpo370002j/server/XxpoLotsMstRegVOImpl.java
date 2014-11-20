/*============================================================================
* �t�@�C���� : XxpoLotsMstRegVOImpl
* �T�v����   : �������b�g�o�^���r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  �˒J�c���     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/***************************************************************************
 * �������b�g�o�^���r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �˒J�c ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoLotsMstRegVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoLotsMstRegVOImpl()
  {
  }
  
  /**
   * ���������\�b�h�B
   * @param lotId ���b�gID
   */
  public void initQuery(Number lotId)
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, lotId);
    executeQuery();
  }

}