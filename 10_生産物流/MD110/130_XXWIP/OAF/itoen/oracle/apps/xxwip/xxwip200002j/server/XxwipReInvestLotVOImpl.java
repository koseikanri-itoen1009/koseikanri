/*============================================================================
* ファイル名 : XxwipReInvestLotVOImpl
* 概要説明   : 打込ロット情報ビューオブジェクト
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-25 1.0  二瓶大輔     新規作成
* 2008-09-10 1.1  二瓶大輔     結合テスト指摘対応No30
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
/***************************************************************************
 * 打込ロット情報ビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.1
 ***************************************************************************
 */
public class XxwipReInvestLotVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipReInvestLotVOImpl()
  {
  }
  /*****************************************************************************
   * 打込割当取得SQLを実行します
   * @param mtlDtlId - 生産原料詳細ID
   ****************************************************************************/
  public void initQuery(String mtlDtlId) 
  {
    if (!XxcmnUtility.isBlankOrNull(mtlDtlId))
    {
      setWhereClauseParams(null); // Always reset
      setWhereClauseParam(0, mtlDtlId);
// 2008-09-10 v1.1 D.Nihei Add Start
      setWhereClauseParam(1, mtlDtlId);
      setWhereClauseParam(2, mtlDtlId);
// 2008-09-10 v1.1 D.Nihei Add End
      executeQuery();
    }
  }
}