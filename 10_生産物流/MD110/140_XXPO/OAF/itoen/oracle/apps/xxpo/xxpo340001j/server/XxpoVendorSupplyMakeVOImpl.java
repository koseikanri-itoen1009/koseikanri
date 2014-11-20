/*============================================================================
* �t�@�C���� : XxpoVendorSupplyMakeVOImpl
* �T�v����   : �O���o������:�o�^�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-01-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �O���o������:�o�^�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyMakeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoVendorSupplyMakeVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchTxnsId         - �����p�����[�^����ID
   ****************************************************************************/
  public void initQuery(
    String  searchTxnsId         // �����p�����[�^����ID
   )
  {
    // ������
    setWhereClauseParams(null);
          
    // WHERE��̃o�C���h�ϐ��Ɍ����l���Z�b�g
    setWhereClauseParam(0, searchTxnsId);
  
    // SELECT�����s
    executeQuery();
  }
}