/*============================================================================
* �t�@�C���� : XxwshLineShipVOImpl
* �T�v����   : ���׏�񃊁[�W����(�o��)�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  �k�������v     �V�K�쐬
*============================================================================
*/

package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

/***************************************************************************
 * ���׏�񃊁[�W����(�o��)�r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �k���� ���v
 * @version 1.0
 ***************************************************************************
 */
public class XxwshLineShipVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshLineShipVOImpl()
  {
  }

  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param lineId - ��������
   ****************************************************************************/
  public void initQuery(
    String lineId)
  {
    if (!XxcmnUtility.isBlankOrNull(lineId))
    {
      // WHERE���������
      setWhereClauseParams(null); // Always reset
      // �o�C���h�ϐ��ɒl���Z�b�g
      setWhereClauseParam(0,  lineId); // ��������
      // �������s
      executeQuery();
    }
  }
}