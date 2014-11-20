/*============================================================================
* �t�@�C���� : XxwipQtInspectionSummaryVOImpl
* �T�v����   : �i�������˗����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  �˒J�c���     �V�K�쐬
* 2008-05-09 1.1  �F�{ �a�Y      �����ύX�v��#28,41,43�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * �i�������˗����r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �˒J�c ���
 * @version 1.0
 ***************************************************************************
 */
public class XxwipQtInspectionSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipQtInspectionSummaryVOImpl()
  {
  }

  /**
   * ���������\�b�h�B
   * @param insReqNo �i�������˗�No
   */
// mod start 1.1
//  public void initQuery(Number insReqNo)
  public void initQuery(String insReqNo)
// mod end 1.1
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, insReqNo);
    executeQuery();
  }

}