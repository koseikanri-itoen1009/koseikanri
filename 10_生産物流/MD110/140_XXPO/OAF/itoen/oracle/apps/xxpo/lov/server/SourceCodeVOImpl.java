/*============================================================================
* �t�@�C���� : SourceCodeVOImpl
* �T�v����   : �Y�nLOV�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-21 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.lov.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �Y�nLOV�r���[�I�u�W�F�N�g�ł��B
 * @author  ORACLE�ɓ��ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class SourceCodeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public SourceCodeVOImpl()
  {
  }
  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   * @param sourceDesc �Y�n
   ***************************************************************************
   */
  public void initQuery(String sourceDesc)
  {
    // WHERE��ɎY�n��ǉ�
    setWhereClause(null);
    setWhereClause(" meaning = :0");
    setWhereClauseParam(0, sourceDesc);

    // �������s
    executeQuery();
  }
}