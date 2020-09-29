/*============================================================================
* ファイル名 : XxcsoInitBmInfoSummaryVOImpl
* 概要説明   : 初期表示時BM情報取得ビューオブジェクトクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- -------------- ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩      新規作成
* 2020-08-21 1.1  SCSK佐々木大和 [E_本稼動_15904]税抜き自販機ＢＭ計算について
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 初期表示時BM情報取得ビューオブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInitBmInfoSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInitBmInfoSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param spDecisionHeaderId SP専決ヘッダーID
   * @param bmClass            BMの種類（BM1,BM2,BM3）
   *****************************************************************************
   */
  public void initQuery(
    Number spDecisionCustomerId
// [E_本稼動_15904] Add Start
   ,Number bmClass
// [E_本稼動_15904] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);
    
// [E_本稼動_15904] Mod Start
//    setWhereClauseParam(0, spDecisionCustomerId);
    setWhereClauseParam(0, bmClass);
    setWhereClauseParam(1, bmClass);
    setWhereClauseParam(2, spDecisionCustomerId);
// [E_本稼動_15904] Add End

    executeQuery();
  }
}